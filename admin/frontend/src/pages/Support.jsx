import { useState, useEffect } from 'react';
import { supportAPI } from '../api';

export default function Support() {
  const [activeTab, setActiveTab] = useState('dashboard');
  const [loading, setLoading] = useState(true);
  const [analytics, setAnalytics] = useState({ openTickets: 0, inProgressTickets: 0, resolvedTickets: 0, pendingComplaints: 0, totalTickets: 0, avgResolutionHours: 4.2 });

  // Tickets tab state
  const [tickets, setTickets] = useState([]);
  const [ticketFilter, setTicketFilter] = useState({ status: 'All', priority: 'All', search: '' });
  const [selectedTicket, setSelectedTicket] = useState(null);
  const [isDrawerOpen, setIsDrawerOpen] = useState(false);
  const [replyMessage, setReplyMessage] = useState('');
  const [isInternalNote, setIsInternalNote] = useState(false);

  // Complaints tab state
  const [complaints, setComplaints] = useState([]);

  // Account requests tab state
  const [accountRequests, setAccountRequests] = useState([]);

  // FAQ tab state
  const [faqs, setFaqs] = useState([]);
  const [faqModalOpen, setFaqModalOpen] = useState(false);
  const [faqForm, setFaqForm] = useState({ id: null, category: 'General', question: '', answer: '', sortOrder: 0 });

  // Policies tab state
  const [policies, setPolicies] = useState([]);
  const [selectedPolicySlug, setSelectedPolicySlug] = useState('privacy');
  const [policyForm, setPolicyForm] = useState({ title: '', content: '' });

  useEffect(() => {
    fetchAnalytics();
    if (activeTab === 'dashboard' || activeTab === 'tickets') fetchTickets();
    if (activeTab === 'complaints') fetchComplaints();
    if (activeTab === 'requests') fetchAccountRequests();
    if (activeTab === 'faqs') fetchFaqs();
    if (activeTab === 'policies') fetchPolicies();
  }, [activeTab, ticketFilter]);

  const fetchAnalytics = async () => {
    try {
      const res = await supportAPI.getAnalytics();
      if (res.data) setAnalytics(res.data.data || res.data);
    } catch (err) {
      console.error('Failed to fetch analytics', err);
    }
  };

  const fetchTickets = async () => {
    try {
      setLoading(true);
      const res = await supportAPI.getTickets(ticketFilter);
      const payload = res.data?.data || res.data;
      const rows = payload?.rows || (Array.isArray(payload) ? payload : []);
      setTickets(rows);
    } catch (err) {
      console.error('Failed to fetch tickets', err);
    } finally {
      setLoading(false);
    }
  };

  const fetchComplaints = async () => {
    try {
      setLoading(true);
      const res = await supportAPI.getWorkerComplaints();
      const payload = res.data?.data || res.data;
      const rows = payload?.rows || (Array.isArray(payload) ? payload : []);
      setComplaints(rows);
    } catch (err) {
      console.error('Failed to fetch worker complaints', err);
    } finally {
      setLoading(false);
    }
  };

  const fetchAccountRequests = async () => {
    try {
      setLoading(true);
      const res = await supportAPI.getAccountRequests();
      const payload = res.data?.data || res.data;
      const rows = payload?.rows || (Array.isArray(payload) ? payload : []);
      setAccountRequests(rows);
    } catch (err) {
      console.error('Failed to fetch account requests', err);
    } finally {
      setLoading(false);
    }
  };

  const fetchFaqs = async () => {
    try {
      setLoading(true);
      const res = await supportAPI.getFaqs();
      const list = res.data?.data || res.data || [];
      setFaqs(Array.isArray(list) ? list : []);
    } catch (err) {
      console.error('Failed to fetch FAQs', err);
    } finally {
      setLoading(false);
    }
  };

  const fetchPolicies = async () => {
    try {
      setLoading(true);
      const res = await supportAPI.getPolicies();
      const list = res.data?.data || res.data || [];
      setPolicies(Array.isArray(list) ? list : []);
      const cur = list.find(p => p.slug === selectedPolicySlug) || list[0];
      if (cur) setPolicyForm({ title: cur.title, content: cur.content });
    } catch (err) {
      console.error('Failed to fetch policies', err);
    } finally {
      setLoading(false);
    }
  };

  const openDrawer = async (ticket) => {
    try {
      const res = await supportAPI.getTicketById(ticket.id);
      setSelectedTicket(res.data?.data || res.data || ticket);
    } catch (_) {
      setSelectedTicket(ticket);
    }
    setIsDrawerOpen(true);
  };

  const closeDrawer = () => {
    setIsDrawerOpen(false);
    setTimeout(() => {
      setSelectedTicket(null);
      setReplyMessage('');
    }, 300);
  };

  const handleStatusUpdate = async (newStatus) => {
    if (!selectedTicket) return;
    try {
      await supportAPI.updateTicketStatus(selectedTicket.id, newStatus);
      fetchTickets();
      fetchAnalytics();
      setSelectedTicket(prev => ({ ...prev, status: newStatus }));
      alert(`Ticket status changed to ${newStatus}`);
    } catch (err) {
      alert(`Error updating status: ${err.message}`);
    }
  };

  const handleSendReply = async () => {
    if (!selectedTicket || !replyMessage.trim()) return;
    try {
      await supportAPI.replyTicket(selectedTicket.id, replyMessage, isInternalNote);
      setReplyMessage('');
      // Refresh ticket details
      const res = await supportAPI.getTicketById(selectedTicket.id);
      setSelectedTicket(res.data);
      fetchTickets();
      alert(isInternalNote ? 'Internal note added' : 'Reply sent to user');
    } catch (err) {
      alert(`Error sending reply: ${err.message}`);
    }
  };

  const handleWorkerAction = async (complaintId, action) => {
    try {
      await supportAPI.updateWorkerComplaint(complaintId, {
        status: 'Resolved',
        adminAction: action,
        adminNotes: `Action ${action} executed by admin`
      });
      fetchComplaints();
      fetchAnalytics();
      alert(`Action "${action}" recorded on complaint.`);
    } catch (err) {
      alert(`Error taking action: ${err.message}`);
    }
  };

  const handleAccountRequestAction = async (requestId, status) => {
    try {
      await supportAPI.updateAccountRequest(requestId, status, `Request ${status.toLowerCase()} by admin`);
      fetchAccountRequests();
      alert(`Account request ${status.toLowerCase()}`);
    } catch (err) {
      alert(`Error updating request: ${err.message}`);
    }
  };

  const handleSaveFaq = async (e) => {
    e.preventDefault();
    try {
      if (faqForm.id) {
        await supportAPI.updateFaq(faqForm.id, faqForm);
      } else {
        await supportAPI.createFaq(faqForm);
      }
      setFaqModalOpen(false);
      fetchFaqs();
      alert('FAQ saved successfully');
    } catch (err) {
      alert(`Error saving FAQ: ${err.message}`);
    }
  };

  const handleDeleteFaq = async (id) => {
    if (!window.confirm('Are you sure you want to delete this FAQ?')) return;
    try {
      await supportAPI.deleteFaq(id);
      fetchFaqs();
    } catch (err) {
      alert(`Error deleting FAQ: ${err.message}`);
    }
  };

  const handleSavePolicy = async (e) => {
    e.preventDefault();
    try {
      await supportAPI.updatePolicy(selectedPolicySlug, policyForm);
      fetchPolicies();
      alert('Policy document published successfully!');
    } catch (err) {
      alert(`Error saving policy: ${err.message}`);
    }
  };

  const getStatusBadge = (status) => {
    switch (status?.toLowerCase()) {
      case 'open':
        return <span className="px-2.5 py-1 rounded-full text-xs font-semibold bg-red-100 text-red-800 border border-red-200">Open</span>;
      case 'in progress':
      case 'in_progress':
        return <span className="px-2.5 py-1 rounded-full text-xs font-semibold bg-blue-100 text-blue-800 border border-blue-200">In Progress</span>;
      case 'resolved':
        return <span className="px-2.5 py-1 rounded-full text-xs font-semibold bg-green-100 text-green-800 border border-green-200">Resolved</span>;
      case 'closed':
        return <span className="px-2.5 py-1 rounded-full text-xs font-semibold bg-gray-100 text-gray-800 border border-gray-200">Closed</span>;
      default:
        return <span className="px-2.5 py-1 rounded-full text-xs font-semibold bg-amber-100 text-amber-800 border border-amber-200">{status}</span>;
    }
  };

  return (
    <div className="flex-1 p-8 bg-gray-50 overflow-auto font-sans relative">
      <div className="max-w-7xl mx-auto">
        
        {/* Header */}
        <div className="flex items-center justify-between mb-6">
          <div>
            <h1 className="text-2xl font-bold text-gray-900">Help & Support Hub</h1>
            <p className="text-sm text-gray-500 mt-1">Manage user tickets, worker complaints, account requests, FAQs, and platform policies.</p>
          </div>
        </div>

        {/* Tab Navigation Bar */}
        <div className="flex space-x-1 border-b border-gray-200 mb-6 bg-white p-1.5 rounded-xl border shadow-sm">
          {[
            { id: 'dashboard', label: 'Overview Metrics' },
            { id: 'tickets', label: 'All Tickets' },
            { id: 'complaints', label: 'Worker Complaints' },
            { id: 'requests', label: 'Account Requests' },
            { id: 'faqs', label: 'FAQ Management' },
            { id: 'policies', label: 'Policies Editor' },
          ].map(tab => (
            <button
              key={tab.id}
              onClick={() => setActiveTab(tab.id)}
              className={`px-4 py-2 text-sm font-semibold rounded-lg transition-all ${activeTab === tab.id ? 'bg-gray-900 text-white shadow-sm' : 'text-gray-600 hover:text-gray-900 hover:bg-gray-100'}`}
            >
              {tab.label}
            </button>
          ))}
        </div>

        {/* TAB 1: DASHBOARD METRICS */}
        {activeTab === 'dashboard' && (
          <div className="space-y-6">
            <div className="grid grid-cols-1 md:grid-cols-4 gap-5">
              <div className="bg-white p-6 rounded-xl border border-gray-200 shadow-sm flex items-center justify-between">
                <div>
                  <div className="text-xs font-bold text-red-500 uppercase tracking-wider">Open Tickets</div>
                  <div className="text-3xl font-extrabold text-gray-900 mt-2">{analytics.openTickets}</div>
                </div>
                <div className="w-12 h-12 bg-red-50 text-red-600 rounded-xl flex items-center justify-center font-bold text-lg">!</div>
              </div>
              <div className="bg-white p-6 rounded-xl border border-gray-200 shadow-sm flex items-center justify-between">
                <div>
                  <div className="text-xs font-bold text-blue-500 uppercase tracking-wider">In Progress</div>
                  <div className="text-3xl font-extrabold text-gray-900 mt-2">{analytics.inProgressTickets}</div>
                </div>
                <div className="w-12 h-12 bg-blue-50 text-blue-600 rounded-xl flex items-center justify-center font-bold text-lg">⏳</div>
              </div>
              <div className="bg-white p-6 rounded-xl border border-gray-200 shadow-sm flex items-center justify-between">
                <div>
                  <div className="text-xs font-bold text-green-500 uppercase tracking-wider">Resolved</div>
                  <div className="text-3xl font-extrabold text-gray-900 mt-2">{analytics.resolvedTickets}</div>
                </div>
                <div className="w-12 h-12 bg-green-50 text-green-600 rounded-xl flex items-center justify-center font-bold text-lg">✓</div>
              </div>
              <div className="bg-white p-6 rounded-xl border border-gray-200 shadow-sm flex items-center justify-between">
                <div>
                  <div className="text-xs font-bold text-purple-500 uppercase tracking-wider">Worker Complaints</div>
                  <div className="text-3xl font-extrabold text-gray-900 mt-2">{analytics.pendingComplaints}</div>
                </div>
                <div className="w-12 h-12 bg-purple-50 text-purple-600 rounded-xl flex items-center justify-center font-bold text-lg">🛡️</div>
              </div>
            </div>

            {/* Quick Actions & Recent Tickets Table */}
            <div className="bg-white rounded-xl border border-gray-200 p-6 shadow-sm">
              <h3 className="text-lg font-bold text-gray-900 mb-4">Recent Support Tickets</h3>
              <div className="overflow-x-auto">
                <table className="w-full text-left border-collapse">
                  <thead>
                    <tr className="border-b border-gray-200 text-xs font-bold text-gray-500 uppercase">
                      <th className="py-3 px-4">Ticket Number</th>
                      <th className="py-3 px-4">Subject</th>
                      <th className="py-3 px-4">Category</th>
                      <th className="py-3 px-4">Status</th>
                      <th className="py-3 px-4 text-right">Action</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-gray-100">
                    {tickets.slice(0, 5).map(t => (
                      <tr key={t.id} className="hover:bg-gray-50 cursor-pointer" onClick={() => openDrawer(t)}>
                        <td className="py-3 px-4 font-bold text-gray-900">{t.ticket_number || `#${t.id}`}</td>
                        <td className="py-3 px-4 text-sm text-gray-800">{t.subject}</td>
                        <td className="py-3 px-4 text-xs font-semibold text-gray-500">{t.category_name || 'General'}</td>
                        <td className="py-3 px-4">{getStatusBadge(t.status)}</td>
                        <td className="py-3 px-4 text-right">
                          <button onClick={(e) => { e.stopPropagation(); openDrawer(t); }} className="text-sm text-blue-600 hover:text-blue-800 font-semibold">
                            View Log
                          </button>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        )}

        {/* TAB 2: TICKETS TABLE */}
        {activeTab === 'tickets' && (
          <div className="space-y-4">
            {/* Filters */}
            <div className="bg-white p-4 rounded-xl border border-gray-200 shadow-sm flex flex-wrap gap-4 items-center justify-between">
              <div className="flex gap-3 items-center">
                <input
                  type="text"
                  placeholder="Search SUP-XXXXXX or subject..."
                  value={ticketFilter.search}
                  onChange={(e) => setTicketFilter(prev => ({ ...prev, search: e.target.value }))}
                  className="px-4 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-blue-500 outline-none w-64"
                />
                <select
                  value={ticketFilter.status}
                  onChange={(e) => setTicketFilter(prev => ({ ...prev, status: e.target.value }))}
                  className="px-3 py-2 border border-gray-300 rounded-lg text-sm text-gray-700 outline-none"
                >
                  <option value="All">All Statuses</option>
                  <option value="Open">Open</option>
                  <option value="In Progress">In Progress</option>
                  <option value="Resolved">Resolved</option>
                  <option value="Closed">Closed</option>
                </select>
              </div>
            </div>

            {/* Table */}
            <div className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
              <table className="w-full text-left border-collapse">
                <thead>
                  <tr className="bg-gray-50 border-b border-gray-200 text-xs uppercase tracking-wider text-gray-500">
                    <th className="px-6 py-4 font-semibold">Ticket ID</th>
                    <th className="px-6 py-4 font-semibold">Subject</th>
                    <th className="px-6 py-4 font-semibold">User</th>
                    <th className="px-6 py-4 font-semibold">Category</th>
                    <th className="px-6 py-4 font-semibold">Date</th>
                    <th className="px-6 py-4 font-semibold">Status</th>
                    <th className="px-6 py-4 font-semibold text-right">Actions</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-200">
                  {loading ? (
                    <tr><td colSpan="7" className="p-8 text-center text-gray-500">Loading support tickets...</td></tr>
                  ) : tickets.length === 0 ? (
                    <tr><td colSpan="7" className="p-8 text-center text-gray-500">No support tickets found.</td></tr>
                  ) : (
                    tickets.map(ticket => (
                      <tr key={ticket.id} className="hover:bg-gray-50 transition-colors cursor-pointer" onClick={() => openDrawer(ticket)}>
                        <td className="px-6 py-4 font-bold text-gray-900">{ticket.ticket_number || `#${ticket.id}`}</td>
                        <td className="px-6 py-4 text-sm text-gray-900 font-medium">{ticket.subject}</td>
                        <td className="px-6 py-4 text-sm text-gray-600">{ticket.user_name || `User #${ticket.user_id}`}</td>
                        <td className="px-6 py-4 text-xs font-semibold text-gray-500">{ticket.category_name || 'General'}</td>
                        <td className="px-6 py-4 text-sm text-gray-600">{new Date(ticket.created_at).toLocaleDateString()}</td>
                        <td className="px-6 py-4">{getStatusBadge(ticket.status)}</td>
                        <td className="px-6 py-4 text-right">
                          <button onClick={(e) => { e.stopPropagation(); openDrawer(ticket); }} className="text-blue-600 hover:text-blue-800 text-sm font-semibold">
                            Open Ticket
                          </button>
                        </td>
                      </tr>
                    ))
                  )}
                </tbody>
              </table>
            </div>
          </div>
        )}

        {/* TAB 3: WORKER COMPLAINTS */}
        {activeTab === 'complaints' && (
          <div className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="bg-gray-50 border-b border-gray-200 text-xs uppercase tracking-wider text-gray-500">
                  <th className="px-6 py-4 font-semibold">Report #</th>
                  <th className="px-6 py-4 font-semibold">Worker</th>
                  <th className="px-6 py-4 font-semibold">Reason</th>
                  <th className="px-6 py-4 font-semibold">Description</th>
                  <th className="px-6 py-4 font-semibold">Status</th>
                  <th className="px-6 py-4 font-semibold text-right">Disciplinary Action</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-200">
                {loading ? (
                  <tr><td colSpan="6" className="p-8 text-center text-gray-500">Loading complaints...</td></tr>
                ) : complaints.length === 0 ? (
                  <tr><td colSpan="6" className="p-8 text-center text-gray-500">No worker complaints registered.</td></tr>
                ) : (
                  complaints.map(c => (
                    <tr key={c.id} className="hover:bg-gray-50">
                      <td className="px-6 py-4 font-bold text-gray-900">{c.report_number || `PR-#${c.id}`}</td>
                      <td className="px-6 py-4 text-sm font-semibold text-gray-900">{c.worker_name || `Worker #${c.worker_id}`}</td>
                      <td className="px-6 py-4 text-sm font-bold text-red-600">{c.reason}</td>
                      <td className="px-6 py-4 text-sm text-gray-600 max-w-xs truncate">{c.description}</td>
                      <td className="px-6 py-4">{getStatusBadge(c.status)}</td>
                      <td className="px-6 py-4 text-right space-x-2">
                        <button onClick={() => handleWorkerAction(c.id, 'Warn Worker')} className="px-2.5 py-1 text-xs font-bold bg-amber-100 text-amber-800 rounded hover:bg-amber-200">
                          Warn
                        </button>
                        <button onClick={() => handleWorkerAction(c.id, 'Suspend Worker')} className="px-2.5 py-1 text-xs font-bold bg-orange-100 text-orange-800 rounded hover:bg-orange-200">
                          Suspend
                        </button>
                        <button onClick={() => handleWorkerAction(c.id, 'Blacklist Worker')} className="px-2.5 py-1 text-xs font-bold bg-red-100 text-red-800 rounded hover:bg-red-200">
                          Blacklist
                        </button>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        )}

        {/* TAB 4: ACCOUNT REQUESTS */}
        {activeTab === 'requests' && (
          <div className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="bg-gray-50 border-b border-gray-200 text-xs uppercase tracking-wider text-gray-500">
                  <th className="px-6 py-4 font-semibold">Req #</th>
                  <th className="px-6 py-4 font-semibold">User</th>
                  <th className="px-6 py-4 font-semibold">Request Type</th>
                  <th className="px-6 py-4 font-semibold">Reason / Details</th>
                  <th className="px-6 py-4 font-semibold">Status</th>
                  <th className="px-6 py-4 font-semibold text-right">Approve / Reject</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-200">
                {loading ? (
                  <tr><td colSpan="6" className="p-8 text-center text-gray-500">Loading requests...</td></tr>
                ) : accountRequests.length === 0 ? (
                  <tr><td colSpan="6" className="p-8 text-center text-gray-500">No pending account requests.</td></tr>
                ) : (
                  accountRequests.map(r => (
                    <tr key={r.id} className="hover:bg-gray-50">
                      <td className="px-6 py-4 font-bold text-gray-900">{r.request_number || `REQ-#${r.id}`}</td>
                      <td className="px-6 py-4 text-sm font-medium text-gray-900">{r.user_name} ({r.user_phone || r.user_email})</td>
                      <td className="px-6 py-4 text-sm font-bold capitalize text-purple-700">{r.request_type.replace('_', ' ')}</td>
                      <td className="px-6 py-4 text-sm text-gray-600">{r.reason || JSON.stringify(r.details)}</td>
                      <td className="px-6 py-4">{getStatusBadge(r.status)}</td>
                      <td className="px-6 py-4 text-right space-x-2">
                        {r.status === 'Pending' ? (
                          <>
                            <button onClick={() => handleAccountRequestAction(r.id, 'Approved')} className="px-3 py-1 text-xs font-bold bg-green-600 text-white rounded hover:bg-green-700">
                              Approve
                            </button>
                            <button onClick={() => handleAccountRequestAction(r.id, 'Rejected')} className="px-3 py-1 text-xs font-bold bg-gray-200 text-gray-700 rounded hover:bg-gray-300">
                              Reject
                            </button>
                          </>
                        ) : (
                          <span className="text-xs text-gray-400 font-semibold">{r.status}</span>
                        )}
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        )}

        {/* TAB 5: FAQ MANAGEMENT */}
        {activeTab === 'faqs' && (
          <div className="space-y-4">
            <div className="flex justify-between items-center bg-white p-4 rounded-xl border border-gray-200">
              <h3 className="font-bold text-gray-900">Dynamic FAQ Management</h3>
              <button
                onClick={() => {
                  setFaqForm({ id: null, category: 'General', question: '', answer: '', sortOrder: 0 });
                  setFaqModalOpen(true);
                }}
                className="px-4 py-2 bg-gray-900 text-white text-sm font-bold rounded-lg hover:bg-gray-800"
              >
                + Add FAQ Item
              </button>
            </div>

            <div className="bg-white rounded-xl border border-gray-200 overflow-hidden shadow-sm">
              <table className="w-full text-left border-collapse">
                <thead>
                  <tr className="bg-gray-50 border-b border-gray-200 text-xs uppercase text-gray-500">
                    <th className="px-6 py-3 font-semibold">Category</th>
                    <th className="px-6 py-3 font-semibold">Question</th>
                    <th className="px-6 py-3 font-semibold">Answer</th>
                    <th className="px-6 py-3 text-right">Actions</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-100">
                  {faqs.map(f => (
                    <tr key={f.id} className="hover:bg-gray-50">
                      <td className="px-6 py-4 text-xs font-bold text-blue-600 uppercase">{f.category}</td>
                      <td className="px-6 py-4 text-sm font-bold text-gray-900">{f.question}</td>
                      <td className="px-6 py-4 text-sm text-gray-600 max-w-md">{f.answer}</td>
                      <td className="px-6 py-4 text-right space-x-2">
                        <button
                          onClick={() => {
                            setFaqForm({ id: f.id, category: f.category, question: f.question, answer: f.answer, sortOrder: f.sort_order });
                            setFaqModalOpen(true);
                          }}
                          className="text-sm font-semibold text-blue-600 hover:text-blue-800"
                        >
                          Edit
                        </button>
                        <button onClick={() => handleDeleteFaq(f.id)} className="text-sm font-semibold text-red-600 hover:text-red-800">
                          Delete
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        )}

        {/* TAB 6: POLICIES EDITOR */}
        {activeTab === 'policies' && (
          <div className="bg-white rounded-xl border border-gray-200 p-6 shadow-sm">
            <div className="flex gap-4 border-b border-gray-200 pb-4 mb-6">
              {[
                { slug: 'privacy', title: 'Privacy Policy' },
                { slug: 'terms', title: 'Terms of Service' },
                { slug: 'cancellation', title: 'Cancellation Policy' },
                { slug: 'refund', title: 'Refund Policy' },
              ].map(p => (
                <button
                  key={p.slug}
                  onClick={() => {
                    setSelectedPolicySlug(p.slug);
                    const found = policies.find(x => x.slug === p.slug);
                    if (found) setPolicyForm({ title: found.title, content: found.content });
                    else setPolicyForm({ title: p.title, content: '' });
                  }}
                  className={`px-4 py-2 font-bold text-sm rounded-lg ${selectedPolicySlug === p.slug ? 'bg-blue-600 text-white' : 'bg-gray-100 text-gray-700'}`}
                >
                  {p.title}
                </button>
              ))}
            </div>

            <form onSubmit={handleSavePolicy} className="space-y-4">
              <div>
                <label className="block text-xs font-bold uppercase text-gray-500 mb-1">Document Title</label>
                <input
                  type="text"
                  value={policyForm.title}
                  onChange={(e) => setPolicyForm(prev => ({ ...prev, title: e.target.value }))}
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg text-sm font-bold text-gray-900"
                />
              </div>

              <div>
                <label className="block text-xs font-bold uppercase text-gray-500 mb-1">Markdown Body Content</label>
                <textarea
                  rows="12"
                  value={policyForm.content}
                  onChange={(e) => setPolicyForm(prev => ({ ...prev, content: e.target.value }))}
                  className="w-full p-4 border border-gray-300 rounded-lg font-mono text-sm leading-relaxed"
                ></textarea>
              </div>

              <button type="submit" className="px-6 py-2.5 bg-gray-900 text-white font-bold rounded-lg hover:bg-gray-800">
                Publish Document
              </button>
            </form>
          </div>
        )}

      </div>

      {/* TICKET DETAILS DRAWER */}
      {isDrawerOpen && (
        <div className="fixed inset-0 bg-black/20 backdrop-blur-sm z-40" onClick={closeDrawer}></div>
      )}

      <div className={`fixed top-0 right-0 h-full w-full max-w-xl bg-white shadow-2xl z-50 transform transition-transform duration-300 flex flex-col ${isDrawerOpen ? 'translate-x-0' : 'translate-x-full'}`}>
        {selectedTicket && (
          <>
            <div className="p-6 border-b border-gray-100 flex justify-between items-center">
              <div>
                <h2 className="text-xl font-extrabold text-gray-900">{selectedTicket.ticket_number || `#${selectedTicket.id}`}</h2>
                <div className="mt-1">{getStatusBadge(selectedTicket.status)}</div>
              </div>
              <button onClick={closeDrawer} className="text-gray-400 hover:text-gray-600 text-xl font-bold">✕</button>
            </div>

            <div className="flex-1 overflow-y-auto p-6 space-y-6">
              <div>
                <h4 className="text-xs font-bold uppercase text-gray-400 mb-2">User Information</h4>
                <div className="bg-gray-50 p-4 rounded-lg text-sm text-gray-800 space-y-1">
                  <div><strong>Name:</strong> {selectedTicket.user_name || 'N/A'}</div>
                  <div><strong>Phone:</strong> {selectedTicket.user_phone || 'N/A'}</div>
                  <div><strong>Email:</strong> {selectedTicket.user_email || 'N/A'}</div>
                </div>
              </div>

              <div>
                <h4 className="text-xs font-bold uppercase text-gray-400 mb-2">Subject & Description</h4>
                <div className="bg-blue-50/50 border border-blue-100 p-4 rounded-lg">
                  <div className="font-bold text-gray-900 mb-1">{selectedTicket.subject}</div>
                  <div className="text-sm text-gray-700">{selectedTicket.description}</div>
                </div>
              </div>

              {/* Chat Timeline */}
              <div>
                <h4 className="text-xs font-bold uppercase text-gray-400 mb-3">Conversation Timeline</h4>
                <div className="space-y-3">
                  {(selectedTicket.messages || []).map(m => (
                    <div key={m.id} className={`p-3.5 rounded-xl text-sm ${m.is_internal_note ? 'bg-amber-50 border border-amber-200' : m.sender_type === 'admin' ? 'bg-blue-50 border border-blue-100 ml-6' : 'bg-gray-100 mr-6'}`}>
                      <div className="flex justify-between text-xs font-bold text-gray-500 mb-1">
                        <span>{m.sender_display_name || m.sender_type}</span>
                        <span>{new Date(m.created_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}</span>
                      </div>
                      <div className="text-gray-800">{m.message}</div>
                    </div>
                  ))}
                </div>
              </div>

              {/* Admin Reply Form */}
              <div>
                <h4 className="text-xs font-bold uppercase text-gray-400 mb-2">Send Admin Response</h4>
                <textarea
                  rows="3"
                  value={replyMessage}
                  onChange={(e) => setReplyMessage(e.target.value)}
                  placeholder="Type response to user..."
                  className="w-full p-3 border border-gray-300 rounded-lg text-sm outline-none focus:ring-2 focus:ring-blue-500"
                ></textarea>
                <div className="flex items-center justify-between mt-2">
                  <label className="flex items-center text-xs text-gray-600 font-semibold cursor-pointer">
                    <input type="checkbox" checked={isInternalNote} onChange={(e) => setIsInternalNote(e.target.checked)} className="mr-2" />
                    Internal Admin Note Only
                  </label>
                  <button onClick={handleSendReply} className="px-4 py-2 bg-blue-600 text-white font-bold text-sm rounded-lg hover:bg-blue-700">
                    Send Reply
                  </button>
                </div>
              </div>
            </div>

            {/* Drawer Footer Actions */}
            <div className="p-6 border-t border-gray-100 bg-gray-50">
              <h4 className="text-xs font-bold uppercase text-gray-400 mb-2">Update Ticket Status</h4>
              <div className="grid grid-cols-4 gap-2">
                {['Open', 'In Progress', 'Resolved', 'Closed'].map(st => (
                  <button
                    key={st}
                    onClick={() => handleStatusUpdate(st)}
                    className={`py-2 text-xs font-bold rounded-lg border ${selectedTicket.status === st ? 'bg-gray-900 text-white' : 'bg-white text-gray-700 border-gray-200'}`}
                  >
                    {st}
                  </button>
                ))}
              </div>
            </div>
          </>
        )}
      </div>

      {/* FAQ MODAL */}
      {faqModalOpen && (
        <div className="fixed inset-0 bg-black/40 backdrop-blur-sm z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl max-w-lg w-full p-6 shadow-2xl">
            <h3 className="text-lg font-extrabold text-gray-900 mb-4">{faqForm.id ? 'Edit FAQ Item' : 'Add FAQ Item'}</h3>
            <form onSubmit={handleSaveFaq} className="space-y-4">
              <div>
                <label className="block text-xs font-bold uppercase text-gray-500 mb-1">Category</label>
                <select
                  value={faqForm.category}
                  onChange={(e) => setFaqForm(prev => ({ ...prev, category: e.target.value }))}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm"
                >
                  <option value="General">General</option>
                  <option value="Booking">Booking</option>
                  <option value="Payment">Payment</option>
                  <option value="Safety">Safety</option>
                </select>
              </div>
              <div>
                <label className="block text-xs font-bold uppercase text-gray-500 mb-1">Question</label>
                <input
                  type="text"
                  required
                  value={faqForm.question}
                  onChange={(e) => setFaqForm(prev => ({ ...prev, question: e.target.value }))}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm"
                />
              </div>
              <div>
                <label className="block text-xs font-bold uppercase text-gray-500 mb-1">Answer</label>
                <textarea
                  rows="4"
                  required
                  value={faqForm.answer}
                  onChange={(e) => setFaqForm(prev => ({ ...prev, answer: e.target.value }))}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm"
                ></textarea>
              </div>
              <div className="flex justify-end gap-2 pt-2">
                <button type="button" onClick={() => setFaqModalOpen(false)} className="px-4 py-2 text-sm font-semibold text-gray-600">
                  Cancel
                </button>
                <button type="submit" className="px-4 py-2 text-sm font-bold bg-gray-900 text-white rounded-lg">
                  Save FAQ
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

    </div>
  );
}
