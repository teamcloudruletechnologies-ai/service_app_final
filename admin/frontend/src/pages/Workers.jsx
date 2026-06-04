import { useState, useEffect } from 'react';
import { workersAPI } from '../api';

export default function Workers() {
  const [workers, setWorkers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [selectedWorker, setSelectedWorker] = useState(null);
  const [isDrawerOpen, setIsDrawerOpen] = useState(false);

  useEffect(() => {
    fetchWorkers();
  }, []);

  const fetchWorkers = async () => {
    try {
      setLoading(true);
      const res = await workersAPI.getAll();
      // Depending on API pagination structure, it might be res.data or res.data.data
      setWorkers(res.data?.rows || res.data?.data || res.data || []);
    } catch (err) {
      console.error('Failed to fetch workers', err);
    } finally {
      setLoading(false);
    }
  };

  const openDrawer = (worker) => {
    setSelectedWorker(worker);
    setIsDrawerOpen(true);
  };

  const closeDrawer = () => {
    setIsDrawerOpen(false);
    setTimeout(() => setSelectedWorker(null), 300); // clear after animation
  };

  const handleStatusChange = async (action) => {
    if (!selectedWorker) return;
    try {
      if (action === 'activate') {
        await workersAPI.activate(selectedWorker.id);
      } else {
        await workersAPI.suspend(selectedWorker.id);
      }
      // Refresh list and close drawer
      await fetchWorkers();
      closeDrawer();
    } catch (err) {
      console.error(`Failed to ${action} worker`, err);
      alert(`Error: ${err.message || 'Action failed'}`);
    }
  };

  const getStatusBadge = (status) => {
    switch (status) {
      case 'active':
        return <span className="px-2.5 py-1 rounded-full text-xs font-medium bg-green-100 text-green-800 border border-green-200">Active</span>;
      case 'suspended':
        return <span className="px-2.5 py-1 rounded-full text-xs font-medium bg-red-100 text-red-800 border border-red-200">Suspended</span>;
      default:
        return <span className="px-2.5 py-1 rounded-full text-xs font-medium bg-yellow-100 text-yellow-800 border border-yellow-200">{status}</span>;
    }
  };

  return (
    <div className="flex-1 p-8 bg-gray-50 overflow-auto font-sans relative">
      <div className="max-w-6xl mx-auto">
        
        {/* Header */}
        <div className="flex items-center justify-between mb-8">
          <div>
            <h1 className="text-2xl font-bold text-gray-900">Worker Management</h1>
            <p className="text-sm text-gray-500 mt-1">Manage service providers, track performance, and handle account status.</p>
          </div>
        </div>

        {/* Table Container */}
        <div className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="bg-gray-50 border-b border-gray-200 text-xs uppercase tracking-wider text-gray-500">
                  <th className="px-6 py-4 font-semibold">Worker Name</th>
                  <th className="px-6 py-4 font-semibold">Contact</th>
                  <th className="px-6 py-4 font-semibold">Service Type</th>
                  <th className="px-6 py-4 font-semibold">City</th>
                  <th className="px-6 py-4 font-semibold">Status</th>
                  <th className="px-6 py-4 font-semibold text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-200">
                {loading ? (
                  <tr>
                    <td colSpan="6" className="px-6 py-12 text-center text-gray-500">
                      Loading workers...
                    </td>
                  </tr>
                ) : workers.length === 0 ? (
                  <tr>
                    <td colSpan="6" className="px-6 py-12 text-center text-gray-500">
                      No workers found.
                    </td>
                  </tr>
                ) : (
                  workers.map((worker) => (
                    <tr key={worker.id} className="hover:bg-gray-50 transition-colors cursor-pointer" onClick={() => openDrawer(worker)}>
                      <td className="px-6 py-4">
                        <div className="flex items-center gap-3">
                          <div className="w-8 h-8 rounded-full bg-blue-100 text-blue-600 flex items-center justify-center font-bold text-xs">
                            {worker.name.charAt(0).toUpperCase()}
                          </div>
                          <div>
                            <div className="font-medium text-gray-900">{worker.name}</div>
                          </div>
                        </div>
                      </td>
                      <td className="px-6 py-4">
                        <div className="text-sm text-gray-900">{worker.phone}</div>
                        <div className="text-xs text-gray-500">{worker.email || 'No email'}</div>
                      </td>
                      <td className="px-6 py-4 text-sm text-gray-600">
                        {worker.service_type || 'Unassigned'}
                      </td>
                      <td className="px-6 py-4 text-sm text-gray-600">
                        {worker.city || 'N/A'}
                      </td>
                      <td className="px-6 py-4">
                        {getStatusBadge(worker.status)}
                      </td>
                      <td className="px-6 py-4 text-right">
                        <button 
                          onClick={(e) => { e.stopPropagation(); openDrawer(worker); }}
                          className="text-blue-600 hover:text-blue-800 text-sm font-medium"
                        >
                          View Details
                        </button>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </div>
      </div>

      {/* Drawer Overlay */}
      {isDrawerOpen && (
        <div 
          className="fixed inset-0 bg-black/20 backdrop-blur-sm z-40 transition-opacity"
          onClick={closeDrawer}
        ></div>
      )}

      {/* Side Drawer */}
      <div 
        className={`fixed top-0 right-0 h-full w-full max-w-md bg-white shadow-2xl z-50 transform transition-transform duration-300 ease-in-out flex flex-col ${isDrawerOpen ? 'translate-x-0' : 'translate-x-full'}`}
      >
        {selectedWorker && (
          <>
            {/* Drawer Header */}
            <div className="flex items-center justify-between p-6 border-b border-gray-100">
              <h2 className="text-xl font-bold text-gray-900">Worker Profile</h2>
              <button 
                onClick={closeDrawer}
                className="text-gray-400 hover:text-gray-600 p-2 rounded-full hover:bg-gray-100 transition-colors"
              >
                ✕
              </button>
            </div>

            {/* Drawer Content */}
            <div className="flex-1 overflow-y-auto p-6">
              
              <div className="flex items-center gap-4 mb-8">
                <div className="w-16 h-16 rounded-full bg-blue-100 text-blue-600 flex items-center justify-center font-bold text-2xl shadow-sm">
                  {selectedWorker.name.charAt(0).toUpperCase()}
                </div>
                <div>
                  <h3 className="text-xl font-bold text-gray-900">{selectedWorker.name}</h3>
                  <p className="text-sm text-gray-500">Joined {new Date(selectedWorker.created_at).toLocaleDateString()}</p>
                </div>
              </div>

              <div className="space-y-6">
                <div>
                  <h4 className="text-xs font-bold uppercase tracking-wider text-gray-400 mb-3">Contact Information</h4>
                  <div className="bg-gray-50 rounded-lg p-4 space-y-3 border border-gray-100">
                    <div className="flex justify-between">
                      <span className="text-sm text-gray-500">Phone</span>
                      <span className="text-sm font-medium text-gray-900">{selectedWorker.phone}</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-sm text-gray-500">Email</span>
                      <span className="text-sm font-medium text-gray-900">{selectedWorker.email || 'N/A'}</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-sm text-gray-500">City</span>
                      <span className="text-sm font-medium text-gray-900">{selectedWorker.city || 'N/A'}</span>
                    </div>
                  </div>
                </div>

                <div>
                  <h4 className="text-xs font-bold uppercase tracking-wider text-gray-400 mb-3">Professional Details</h4>
                  <div className="bg-gray-50 rounded-lg p-4 space-y-3 border border-gray-100">
                    <div className="flex justify-between">
                      <span className="text-sm text-gray-500">Service Type</span>
                      <span className="text-sm font-medium text-gray-900">{selectedWorker.service_type || 'N/A'}</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-sm text-gray-500">Experience</span>
                      <span className="text-sm font-medium text-gray-900">{selectedWorker.experience_years} Years</span>
                    </div>
                    <div className="flex justify-between items-center">
                      <span className="text-sm text-gray-500">Account Status</span>
                      {getStatusBadge(selectedWorker.status)}
                    </div>
                    <div className="flex justify-between items-center">
                      <span className="text-sm text-gray-500">KYC Status</span>
                      <span className="text-sm font-medium text-gray-900 uppercase">{selectedWorker.kyc_status}</span>
                    </div>
                  </div>
                </div>
              </div>

            </div>

            {/* Drawer Footer / Actions */}
            <div className="p-6 border-t border-gray-100 bg-gray-50 flex gap-3">
              {selectedWorker.status === 'active' ? (
                <button 
                  onClick={() => handleStatusChange('suspend')}
                  className="flex-1 bg-white text-red-600 border border-red-200 hover:bg-red-50 py-2.5 rounded-lg text-sm font-semibold transition-colors shadow-sm"
                >
                  Suspend Account
                </button>
              ) : (
                <button 
                  onClick={() => handleStatusChange('activate')}
                  className="flex-1 bg-blue-600 text-white hover:bg-blue-700 py-2.5 rounded-lg text-sm font-semibold transition-colors shadow-sm"
                >
                  Activate Account
                </button>
              )}
            </div>
          </>
        )}
      </div>

    </div>
  );
}
